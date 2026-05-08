package cl.triskeledu.pedido.model;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(
    name = "usuario_proy",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_usuario_proy_email", columnNames = "email")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioProy {

    @Id
    @Column(name = "email", nullable = false, length = 100)
    private String email;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "rol", nullable = false, length = 20)
    private String rol;

    @CreatedDate
    @Column(name = "sincronizado", nullable = false, updatable = false)
    private LocalDateTime sincronizado;

    @OneToMany(mappedBy = "usuario", fetch = FetchType.LAZY)
    private List<Pedido> pedidos;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof UsuarioProy)) return false;
        UsuarioProy that = (UsuarioProy) o;
        return email != null && email.equals(that.email);
    }

    @Override
    public int hashCode() {
        return email != null ? email.hashCode() : 0;
    }
}
