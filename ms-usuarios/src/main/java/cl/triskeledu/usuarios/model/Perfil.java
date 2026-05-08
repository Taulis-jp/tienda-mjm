package cl.triskeledu.usuarios.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "perfil",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_perfil_email", columnNames = "email")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Perfil {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "email", referencedColumnName = "email", nullable = false, unique = true)
    private Usuario usuario;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "telefono", nullable = true, length = 20)
    private String telefono;

    @Column(name = "avatar_url", nullable = true, length = 255)
    private String avatarUrl;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Perfil)) return false;
        Perfil that = (Perfil) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
