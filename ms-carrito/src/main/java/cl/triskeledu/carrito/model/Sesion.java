package cl.triskeledu.carrito.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "sesion",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_sesion_token", columnNames = "token")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Sesion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "email", referencedColumnName = "email", nullable = false)
    private UsuarioProy usuario;

    @Column(name = "token", nullable = false, length = 255, unique = true)
    private String token;

    @Column(name = "expira_at", nullable = false)
    private LocalDateTime expiraAt;

    @Column(name = "activa", nullable = false)
    @Builder.Default
    private Boolean activa = true;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Sesion)) return false;
        Sesion that = (Sesion) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
